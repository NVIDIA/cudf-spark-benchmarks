WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sum(ps.ps_availqty) AS total_available,
        avg(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        count(o.o_orderkey) AS total_orders,
        sum(o.o_totalprice) AS total_spending
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    SUM(COALESCE(ss.total_available, 0)) AS total_parts_available,
    SUM(COALESCE(lis.revenue, 0)) AS total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey
LEFT JOIN 
    LineItemStats lis ON cs.c_custkey = lis.l_orderkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
