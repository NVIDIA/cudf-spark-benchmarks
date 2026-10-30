
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey AS custkey,
        c.c_name AS name,
        c.total_spent,
        c.total_orders,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrders c
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(l.l_orderkey) >= 100
),
FinalBenchmark AS (
    SELECT 
        tc.name AS customer_name,
        tp.p_name AS popular_part,
        tp.order_count,
        sp.s_name AS supplier_name,
        sp.total_available,
        tc.total_spent
    FROM 
        TopCustomers tc
    JOIN 
        PopularParts tp ON tc.total_orders > 5
    JOIN 
        SupplierParts sp ON tp.p_partkey = sp.p_partkey
    WHERE 
        tc.rank <= 10
)
SELECT 
    customer_name,
    popular_part,
    order_count,
    supplier_name,
    total_available,
    total_spent
FROM 
    FinalBenchmark
ORDER BY 
    total_spent DESC, order_count DESC;
