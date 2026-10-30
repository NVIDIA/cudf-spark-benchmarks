WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ProductSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name
),
RankedProducts AS (
    SELECT 
        ps.p_name,
        ps.total_available_qty,
        ps.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ps.total_available_qty DESC) AS rank
    FROM 
        ProductSupplier ps
)
SELECT 
    co.c_name,
    r.p_name,
    r.total_available_qty,
    r.avg_supply_cost,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    CASE 
        WHEN co.total_spent > 1000 THEN 'High Value'
        WHEN co.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CustomerOrders co
RIGHT JOIN 
    RankedProducts r ON co.order_count > 0 
WHERE 
    r.rank <= 10 
ORDER BY 
    customer_value_segment, r.total_available_qty DESC;
