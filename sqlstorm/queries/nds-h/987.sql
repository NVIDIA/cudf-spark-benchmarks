WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS cost_rank
    FROM 
        SupplierStats
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    ss.unique_parts,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    RankedCustomers cs
FULL OUTER JOIN 
    RankedSuppliers ss ON cs.total_orders = ss.unique_parts
WHERE 
    (ss.cost_rank <= 10 OR cs.spending_rank <= 10)
    AND (cs.total_spent IS NOT NULL OR ss.total_supply_cost IS NOT NULL)
ORDER BY 
    cs.c_name, ss.s_name;
