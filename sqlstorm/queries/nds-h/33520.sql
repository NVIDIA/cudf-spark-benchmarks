WITH  Sales_CTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
Part_Supplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
High_Value_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
)
SELECT 
    p.p_name,
    p.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_tax) AS max_tax,
    COALESCE(SUM(ps.total_available), 0) AS total_available_parts,
    COALESCE(AVG(s.s_acctbal), 0) AS avg_supplier_acctbal
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN Part_Supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN High_Value_Suppliers s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2 
    WHERE p2.p_type LIKE 'Metal%'
)
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;
