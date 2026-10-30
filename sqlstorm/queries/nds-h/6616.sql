WITH SupplierTotal AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.order_count, 
        ROW_NUMBER() OVER (ORDER BY c.order_count DESC) AS rank
    FROM 
        CustomerOrderCount c
    WHERE 
        c.order_count > 0
),
PartDetail AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(l.l_extendedprice) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    tc.c_name AS top_customer, 
    SUM(pt.total_sales) AS total_spent,
    st.total_cost AS supplier_cost
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    PartDetail pt ON l.l_partkey = pt.p_partkey
JOIN 
    SupplierTotal st ON l.l_suppkey = st.s_suppkey
GROUP BY 
    tc.c_name, st.total_cost
HAVING 
    SUM(pt.total_sales) > 10000
ORDER BY 
    total_spent DESC;