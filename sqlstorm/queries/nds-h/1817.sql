WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.order_total) AS total_spent,
        COUNT(os.o_orderkey) AS number_of_orders
    FROM 
        customer c
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        ss.unique_parts,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierStats ss
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_spent,
    co.number_of_orders,
    rs.s_name AS top_supplier,
    rs.total_supply_cost,
    rs.unique_parts
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedSuppliers rs ON rs.supply_rank = 1
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    co.total_spent DESC
LIMIT 10;