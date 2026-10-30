
WITH TotalSales AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts_count, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 5
)
SELECT 
    t.c_name AS customer_name,
    t.total_spent,
    COALESCE(ss.supplied_parts_count, 0) AS supplier_parts_count,
    COALESCE(ss.total_supply_cost, 0) AS supplier_total_cost,
    ts.sales_total
FROM 
    TopCustomers t
LEFT JOIN 
    SupplierStats ss ON t.c_custkey = ss.s_suppkey
LEFT JOIN 
    TotalSales ts ON t.c_custkey = ts.o_orderkey
WHERE 
    t.total_spent > (SELECT AVG(total_spent) FROM TopCustomers)
    OR 
    ss.total_supply_cost IS NULL
ORDER BY 
    t.total_spent DESC;
