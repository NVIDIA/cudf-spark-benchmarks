
WITH TotalSales AS (
    SELECT 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS customer_rank
    FROM 
        TotalSales ts
    JOIN 
        customer c ON ts.c_name = c.c_name
)
SELECT 
    tc.c_name,
    COALESCE(ss.part_count, 0) AS supplier_part_count,
    ss.avg_supply_cost,
    CASE 
        WHEN tc.customer_rank <= 10 THEN 'Top 10 Customer' 
        ELSE 'Regular Customer' 
    END AS customer_status,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierStats ss ON tc.c_name = ss.s_name
LEFT JOIN 
    orders o ON tc.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    ss.part_count IS NOT NULL AND 
    ss.avg_supply_cost IS NOT NULL
GROUP BY 
    tc.c_name, ss.part_count, ss.avg_supply_cost, tc.customer_rank
HAVING 
    SUM(l.l_extendedprice) > 1000
ORDER BY 
    tc.customer_rank, ss.avg_supply_cost DESC;
