
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 5
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000.00
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000.00
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        COUNT(*) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, l.l_returnflag, l.l_linestatus, l.l_extendedprice, l.l_discount, l.l_tax
)
SELECT 
    r.s_name AS top_supplier,
    h.c_name AS high_value_customer,
    SUM(r.s_acctbal) AS total_supplier_balance,
    SUM(h.total_spent) AS total_customer_spent,
    SUM(r.rank) AS total_supplier_ranks,
    COUNT(so.o_orderkey) AS recent_order_count
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers h ON r.rank = 1
JOIN 
    RecentOrders so ON so.line_count > 1
GROUP BY 
    r.s_name, h.c_name
HAVING 
    SUM(r.s_acctbal) > 10000.00 AND 
    SUM(h.total_spent) > 10000.00
ORDER BY 
    total_supplier_balance DESC, total_customer_spent DESC;
