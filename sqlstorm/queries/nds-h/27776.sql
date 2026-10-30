WITH supplier_parts AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        p.p_brand AS brand, 
        p.p_type AS type,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' as brand ', p.p_brand, ' of type ', p.p_type) AS supply_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_number,
        o.o_totalprice AS total_price,
        o.o_orderdate AS order_date,
        LAG(o.o_totalprice) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS previous_order_price,
        CASE 
            WHEN LAG(o.o_totalprice) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) IS NOT NULL 
            THEN (o.o_totalprice - LAG(o.o_totalprice) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate)) 
            ELSE 0 
        END AS price_difference
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
detailed_report AS (
    SELECT 
        sp.supplier_name,
        co.customer_name,
        sp.available_quantity,
        sp.supply_cost,
        co.total_price,
        co.previous_order_price,
        co.price_difference,
        CONCAT(sp.supplier_name, ' has provided ', sp.available_quantity, ' units of ', sp.part_name, ' costing ', sp.supply_cost, ' to ', co.customer_name, ' with an order total of ', co.total_price, ' (previous: ', COALESCE(co.previous_order_price, 0), ', diff: ', COALESCE(co.price_difference, 0), ')') AS final_report
    FROM 
        supplier_parts sp
    JOIN 
        customer_orders co ON sp.supplier_name = co.customer_name
)
SELECT 
    supplier_name,
    customer_name,
    available_quantity,
    supply_cost,
    total_price,
    previous_order_price,
    price_difference,
    final_report
FROM 
    detailed_report
WHERE 
    available_quantity > 10 AND total_price > 100.00
ORDER BY 
    total_price DESC;
