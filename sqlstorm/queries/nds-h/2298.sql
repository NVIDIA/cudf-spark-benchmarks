WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierPartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name
)
SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    h.c_name AS high_value_customer,
    s.p_name AS part_name,
    s.avg_supply_cost,
    CASE 
        WHEN r.revenue_rank = 1 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    RankedOrders r
LEFT JOIN 
    HighValueCustomers h ON r.o_orderkey = h.c_custkey
JOIN 
    SupplierPartStats s ON r.o_orderkey = s.p_partkey
WHERE 
    s.avg_supply_cost IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey;
