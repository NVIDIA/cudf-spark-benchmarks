
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.s_name AS supplier_name,
    r.s_acctbal AS supplier_balance,
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    o.total_revenue,
    COALESCE(o.total_revenue, 0) * 0.1 AS revenue_contribution,
    p.p_name AS part_name,
    p.p_retailprice,
    p.p_comment
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    HighValueCustomers c ON r.s_suppkey = c.c_custkey
JOIN 
    RecentOrders o ON o.o_orderkey = r.s_suppkey
JOIN 
    part p ON p.p_partkey = r.s_suppkey
WHERE 
    (c.c_acctbal IS NOT NULL AND r.s_acctbal IS NOT NULL)
    OR (c.c_acctbal IS NULL AND r.s_acctbal IS NULL)
ORDER BY 
    p.p_retailprice DESC, 
    revenue_contribution DESC;
