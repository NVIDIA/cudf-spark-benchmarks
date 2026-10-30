
WITH SupplierTotal AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.c_nationkey,
        RANK() OVER (ORDER BY co.total_orders DESC) AS order_rank
    FROM 
        customer cust
    JOIN 
        CustomerOrders co ON cust.c_custkey = co.c_custkey
    WHERE 
        co.total_orders > (SELECT AVG(total_orders) FROM CustomerOrders)
),
SupplierNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    LEFT JOIN 
        SupplierTotal st ON n.n_nationkey = st.s_nationkey
    WHERE 
        st.total_cost IS NOT NULL
)
SELECT 
    sn.n_name,
    COALESCE(SUM(st.total_cost), 0) AS total_supplier_cost,
    COUNT(tc.c_custkey) AS number_of_top_customers
FROM 
    SupplierNation sn
LEFT JOIN 
    SupplierTotal st ON sn.n_nationkey = st.s_nationkey
LEFT JOIN 
    TopCustomers tc ON sn.n_nationkey = tc.c_nationkey
GROUP BY 
    sn.n_name
HAVING 
    COALESCE(SUM(st.total_cost), 0) > 100000
ORDER BY 
    number_of_top_customers DESC;
