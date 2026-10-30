
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months' 
        AND o.o_orderstatus IN ('O', 'F', 'P')
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(MAX(co.total_spent), 0) AS max_customer_spending,
    SUM(hs.total_value) AS total_supplier_value,
    AVG(ro.o_totalprice) AS avg_order_price
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerSpending co ON co.c_custkey = n.n_nationkey
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_container LIKE '%SMALL%') LIMIT 1)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey NOT IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_orderstatus = 'C') LIMIT 1)
WHERE 
    n.n_comment IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    nation_count DESC, total_supplier_value DESC;
