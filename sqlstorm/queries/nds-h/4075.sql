
WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_name
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    rn.r_name,
    rn.n_name,
    COUNT(DISTINCT od.o_orderkey) AS num_orders,
    SUM(od.total_order_value) AS total_sales_value,
    COUNT(DISTINCT sc.s_suppkey) AS num_suppliers,
    AVG(sc.total_supply_cost) AS avg_supply_cost,
    MAX(od.distinct_parts) AS max_distinct_parts,
    CASE 
        WHEN AVG(sc.total_supply_cost) IS NULL THEN 'No Supplies'
        ELSE 'Supplies Available'
    END AS supply_status
FROM 
    OrderDetails od
JOIN 
    RegionNation rn ON od.o_orderkey % 5 = 0 
LEFT JOIN 
    SupplierCosts sc ON sc.s_suppkey = od.o_orderkey % 10 
GROUP BY 
    rn.r_name, rn.n_name
HAVING 
    SUM(od.total_order_value) > 1000 AND COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY 
    total_sales_value DESC;
