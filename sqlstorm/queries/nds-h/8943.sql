WITH RegionalSupplierSales AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * li.l_quantity) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
    GROUP BY 
        r.r_name, n.n_name, s.s_name
),
Ranking AS (
    SELECT 
        region_name, 
        nation_name, 
        supplier_name, 
        total_supply_cost, 
        total_orders,
        RANK() OVER (PARTITION BY region_name ORDER BY total_supply_cost DESC) AS cost_rank
    FROM 
        RegionalSupplierSales
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    total_supply_cost,
    total_orders,
    cost_rank
FROM 
    Ranking
WHERE 
    cost_rank <= 5
ORDER BY 
    region_name, cost_rank;