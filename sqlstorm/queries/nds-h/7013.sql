WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal > 10000
    GROUP BY
        c.c_custkey, c.c_name, c.c_acctbal
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_extendedprice,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT 
    f.o_orderkey,
    DATE_PART('month', f.o_orderdate) AS order_month,
    h.c_name AS customer_name,
    SUM(f.l_extendedprice * (1 - f.l_discount)) AS net_amount,
    COALESCE(r.s_name, 'Unknown Supplier') AS supplier_name,
    h.order_count,
    s.total_supply_cost
FROM 
    FilteredOrders f
LEFT JOIN 
    HighValueCustomers h ON h.c_custkey = f.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.rank = 1
LEFT JOIN 
    supplier r ON s.s_suppkey = r.s_suppkey
GROUP BY 
    f.o_orderkey, f.o_orderdate, h.c_name, r.s_name, h.order_count, s.total_supply_cost
ORDER BY 
    net_amount DESC
LIMIT 10;