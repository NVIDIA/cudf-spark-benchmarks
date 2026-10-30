WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', CAST(ps.ps_availqty AS STRING), ' units at a cost of $', CAST(ps.ps_supplycost AS DECIMAL(12, 2))) AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        CONCAT(c.c_name, ' has placed ', CAST(COUNT(o.o_orderkey) AS STRING), ' orders totaling $', CAST(SUM(o.o_totalprice) AS DECIMAL(12, 2))) AS order_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    rp.r_name AS region_name,
    COUNT(DISTINCT sp.supplier_name) AS supplier_count,
    COUNT(DISTINCT co.customer_name) AS customer_count,
    STRING_AGG(sp.supply_info, '; ') AS supplier_details,
    STRING_AGG(co.order_summary, '; ') AS customer_orders_summary
FROM 
    region rp
LEFT JOIN 
    nation n ON rp.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_name = sp.supplier_name
LEFT JOIN 
    CustomerOrders co ON co.customer_name = sp.supplier_name
GROUP BY 
    rp.r_name
ORDER BY 
    rp.r_name;
