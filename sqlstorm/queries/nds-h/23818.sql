WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_acctbal IS NOT NULL
        )
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    total_supply_value,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueParts hp ON l.l_partkey = hp.p_partkey
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey = l.l_suppkey
WHERE 
    o.o_totalprice IS NOT NULL 
    AND (o.o_totalprice > 500 OR l.l_discount IS NULL)
    AND (EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = o.o_custkey AND c.c_acctbal > 0) 
          OR s.s_acctbal > 50000)
ORDER BY 
    o.o_orderdate DESC, total_supply_value DESC
LIMIT 100;
