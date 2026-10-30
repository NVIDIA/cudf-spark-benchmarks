WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
SuppliersWithComments AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        CASE 
            WHEN rs.s_acctbal IS NULL THEN 'Unknown Balance'
            ELSE 'Balance: ' || CAST(rs.s_acctbal AS STRING)
        END AS account_details,
        rs.rank
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
TopPartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    GROUP BY 
        ps.ps_partkey
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'P')
    GROUP BY 
        o.o_orderkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.total_price) AS total_spent,
        COUNT(os.o_orderkey) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        OrderStatistics os ON c.c_custkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(swc.s_name, 'No Supplier') AS supplier_name,
    cos.total_spent,
    cos.num_orders,
    CASE 
        WHEN cos.total_spent IS NULL THEN 'No Spend'
        ELSE 'Spent: ' || CAST(cos.total_spent AS STRING)
    END AS spending_info
FROM 
    part p
LEFT JOIN 
    SuppliersWithComments swc ON p.p_partkey = swc.s_suppkey
LEFT JOIN 
    CustomerOrderSummary cos ON p.p_partkey = cos.c_custkey
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
    AND (p.p_comment IS NULL OR LENGTH(p.p_comment) > 20)
ORDER BY 
    p.p_partkey DESC, p.p_name ASC;
