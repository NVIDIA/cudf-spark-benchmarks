WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
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
OrderedSupplier AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_cost,
        ss.part_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_cost DESC) AS rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_cost > (SELECT AVG(total_cost) FROM SupplierStats)
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerOrderStats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
)
SELECT 
    oc.c_name AS Top_Customer,
    os.s_name AS Top_Supplier,
    oc.total_spent AS Total_Spent,
    os.total_cost AS Total_Cost,
    os.part_count AS Parts_Provided
FROM 
    TopCustomers oc
JOIN 
    OrderedSupplier os ON os.rank = 1
WHERE 
    oc.order_count > 0
ORDER BY 
    oc.total_spent DESC;
