
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
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
MaxRevenueOrders AS (
    SELECT 
        year, 
        MAX(total_revenue) AS max_revenue
    FROM (
        SELECT 
            EXTRACT(YEAR FROM o.o_orderdate) AS year,
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY 
            EXTRACT(YEAR FROM o.o_orderdate)
    ) AS yearly_revenue
    GROUP BY 
        year
)
SELECT 
    r.r_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(MIN(mr.max_revenue), 0) AS max_revenue_in_year
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    MaxRevenueOrders mr ON mr.year = EXTRACT(YEAR FROM DATE '1998-10-01')
WHERE 
    s.s_acctbal > 10000
GROUP BY 
    r.r_name
ORDER BY 
    total_supply_cost DESC;
