WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_shipdate >= '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available,
        ss.avg_supply_cost,
        ss.order_count
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.orders_count,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
)

SELECT 
    t.s_suppkey,
    t.s_name,
    COALESCE(r.c_custkey, 0) AS top_customer_key,
    COALESCE(r.c_name, 'No Orders') AS top_customer_name,
    t.total_available,
    t.avg_supply_cost,
    t.order_count,
    r.orders_count,
    r.total_spent
FROM 
    TopSuppliers t
LEFT JOIN 
    RankedCustomers r ON t.order_count = r.orders_count 
WHERE 
    t.total_available > 100 
    AND t.avg_supply_cost < 50.00
ORDER BY 
    t.total_available DESC, r.total_spent DESC;