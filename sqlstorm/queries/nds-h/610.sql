
WITH Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Order_Analysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost_by_nation,
    COUNT(DISTINCT oa.c_custkey) AS total_customers,
    AVG(oa.total_spent) AS avg_spent_per_customer
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    Supplier_Summary ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_mfgr = 'ManufacturerA'
    )
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    Order_Analysis oa ON oa.c_custkey = c.c_custkey
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT oa.c_custkey) > 0
ORDER BY 
    total_supply_cost_by_nation DESC, avg_spent_per_customer DESC;
