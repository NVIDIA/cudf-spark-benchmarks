WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
), CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(os.total_sales), 0) AS total_orders,
        COUNT(DISTINCT os.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        sc.total_supply_cost,
        RANK() OVER (ORDER BY sc.total_supply_cost DESC) as rank
    FROM 
        supplier s
    JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        sc.total_supply_cost IS NOT NULL
)
SELECT 
    cu.c_custkey,
    cu.c_name,
    hvs.s_name AS supplier_name,
    hvs.total_supply_cost,
    cu.total_orders,
    cu.order_count,
    CASE 
        WHEN cu.total_orders > 1000 THEN 'High'
        WHEN cu.total_orders > 500 THEN 'Medium'
        ELSE 'Low' 
    END AS order_value_category
FROM 
    CustomerOrder cu
CROSS JOIN 
    HighValueSuppliers hvs
WHERE 
    hvs.rank <= 10
    AND cu.order_count > 0
ORDER BY 
    cu.total_orders DESC, hvs.total_supply_cost DESC;
