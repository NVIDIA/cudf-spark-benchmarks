WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY total_avail_qty DESC) AS rank
    FROM 
        SupplierStats s
    WHERE 
        total_avail_qty > (
            SELECT AVG(total_avail_qty) 
            FROM SupplierStats
        )
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(co.order_total) AS total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(co.order_total) > 10000
),
SupplierOrderSummary AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_name
)
SELECT 
    tso.s_name AS supplier_name,
    hvc.c_name AS customer_name,
    hvc.total_spent AS total_spent,
    sos.order_count,
    sos.total_revenue,
    CASE 
        WHEN hvc.total_spent IS NULL THEN 'Customer has no orders'
        ELSE 'Customer has placed orders'
    END AS order_status
FROM 
    TopSuppliers tso
FULL OUTER JOIN 
    HighValueCustomers hvc ON tso.s_suppkey = hvc.c_custkey
JOIN 
    SupplierOrderSummary sos ON tso.s_name = sos.s_name
WHERE 
    tso.rank <= 5 
ORDER BY 
    total_spent DESC NULLS LAST;
