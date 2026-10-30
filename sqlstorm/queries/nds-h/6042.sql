WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_cost, 
        ss.total_parts, 
        ss.avg_supplycost,
        RANK() OVER (ORDER BY ss.total_cost DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_parts > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > 0
)
SELECT 
    ts.rank AS supplier_rank,
    ts.s_name AS supplier_name,
    tc.rank AS customer_rank,
    tc.c_name AS customer_name,
    ts.total_cost AS supplier_total_cost,
    tc.total_spent AS customer_total_spent,
    ts.avg_supplycost AS supplier_avg_supplycost,
    ts.total_parts AS supplier_total_parts
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.rank <= 10 AND tc.rank <= 10
ORDER BY 
    ts.rank, tc.rank;
