WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_spent
    FROM 
        CustomerOrderStats c
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
),
RegionSupplierInfo AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ss.total_available) AS total_avail_qty,
        SUM(ss.total_cost) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT h.c_custkey) AS high_value_customer_count,
    SUM(rsi.total_avail_qty) AS total_available_inventory,
    SUM(rsi.total_supply_cost) AS total_supply_value
FROM 
    RegionSupplierInfo rsi
JOIN 
    HighValueCustomers h ON rsi.supplier_count > 0
JOIN 
    region r ON rsi.r_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_supply_value DESC;
