WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderpriority,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderpriority, o.o_totalprice, o.o_orderdate
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    cs.c_name AS customer_name,
    ro.o_orderkey AS order_key,
    ro.o_orderstatus AS order_status,
    ro.total_quantity AS quantity_ordered,
    cs.total_spent AS total_spent,
    ro.o_orderdate AS order_date
FROM 
    RankedOrders ro
JOIN 
    CustomerStats cs ON ro.o_orderkey = cs.total_orders
JOIN 
    supplier s ON s.s_suppkey = ro.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    cs.total_spent > 10000
ORDER BY 
    r.r_name, n.n_name, cs.total_spent DESC, ro.o_orderdate;
