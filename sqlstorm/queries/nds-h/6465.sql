WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
SalesData AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
), 
PerformanceMetrics AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT sd.c_custkey) AS number_of_customers,
        SUM(sd.total_revenue) AS total_sales,
        SUM(rs.total_supply_cost) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        SalesData sd ON n.n_nationkey = sd.c_nationkey
    LEFT JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    pm.nation_name,
    pm.number_of_customers,
    pm.total_sales,
    pm.total_supply_cost,
    ROUND(pm.total_sales / NULLIF(pm.number_of_customers, 0), 2) AS avg_sales_per_customer,
    ROUND(pm.total_supply_cost / NULLIF(pm.number_of_customers, 0), 2) AS avg_supply_cost_per_customer
FROM 
    PerformanceMetrics pm
ORDER BY 
    pm.total_sales DESC, 
    pm.number_of_customers DESC;
