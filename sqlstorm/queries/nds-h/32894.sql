WITH  CustomerOrderCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' OR o.o_orderkey IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierPartCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    c.c_name AS customer_name,
    c.total_spent,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(s.total_parts, 0) AS total_parts,
    CASE 
        WHEN c.total_orders > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS customer_type,
    (CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders'
        ELSE (ROUND(c.total_spent, 2) || ' USD') 
    END) AS formatted_total_spent
FROM 
    CustomerOrderCTE c
LEFT JOIN 
    SupplierPartCTE s ON c.c_custkey = s.s_suppkey 
WHERE 
    c.rn = 1
ORDER BY 
    total_spent DESC
LIMIT 10;