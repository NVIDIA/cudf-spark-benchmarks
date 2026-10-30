
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey AS custkey, 
        c.c_name, 
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrders c
),
ProductSupplier AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_suppkey, 
        s.s_name, 
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrdersWithLineItems AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FinalReport AS (
    SELECT 
        tc.c_name, 
        tc.total_spent, 
        ps.p_name, 
        SUM(owi.order_value) AS total_order_value
    FROM 
        TopCustomers tc
    LEFT JOIN 
        OrdersWithLineItems owi ON tc.custkey = owi.o_orderkey
    JOIN 
        ProductSupplier ps ON owi.o_orderkey = ps.p_partkey
    WHERE 
        tc.rank <= 5
    GROUP BY 
        tc.c_name, tc.total_spent, ps.p_name
)
SELECT 
    f.c_name, 
    f.total_spent, 
    f.p_name, 
    f.total_order_value
FROM 
    FinalReport f
ORDER BY 
    f.total_order_value DESC;
