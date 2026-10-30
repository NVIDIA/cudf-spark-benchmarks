
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE((SELECT SUM(ps.ps_supplycost) 
                  FROM partsupp ps 
                  WHERE ps.ps_suppkey = s.s_suppkey), 0) AS total_supplycost
    FROM 
        supplier s
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown'
            WHEN c.c_acctbal > 1000 THEN 'High'
            ELSE 'Low' 
        END AS account_status
    FROM 
        customer c
    WHERE 
        c.c_nationkey IN (SELECT n.n_nationkey 
                          FROM nation n 
                          WHERE n.n_comment LIKE '%friendly%')
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
FinalOutput AS (
    SELECT 
        r.p_partkey,
        r.p_name,
        COALESCE(s.s_name, 'No Supplier') AS supplier_name,
        c.c_name AS customer_name,
        COALESCE(o.total_price, 0) AS order_total,
        c.account_status
    FROM 
        RankedParts r
    LEFT JOIN 
        SupplierInfo s ON s.total_supplycost = (SELECT MAX(total_supplycost) FROM SupplierInfo)
    LEFT JOIN 
        CustomerDetails c ON c.c_custkey = (SELECT c2.c_custkey FROM CustomerDetails c2 ORDER BY c2.c_acctbal DESC LIMIT 1)
    LEFT JOIN 
        OrderSummary o ON o.o_orderkey = (SELECT o2.o_orderkey FROM OrderSummary o2 ORDER BY o2.total_price DESC LIMIT 1)
    WHERE 
        r.rn = 1 
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    order_total > 1000 OR customer_name IS NOT NULL
ORDER BY 
    supplier_name, account_status DESC, order_total DESC;
