WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), 
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderLineDetails AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(li.l_orderkey) AS item_count
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= DATE '1996-01-01' AND li.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        li.l_orderkey
)

SELECT 
    co.c_custkey,
    co.c_name,
    co.total_spent,
    co.order_count,
    oli.total_revenue,
    oli.item_count,
    psi.total_available,
    psi.total_cost
FROM 
    CustomerOrders co
JOIN 
    OrderLineDetails oli ON co.c_custkey = oli.l_orderkey
JOIN 
    PartSupplierInfo psi ON oli.l_orderkey = psi.ps_partkey
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.total_spent DESC, co.order_count DESC
LIMIT 100;