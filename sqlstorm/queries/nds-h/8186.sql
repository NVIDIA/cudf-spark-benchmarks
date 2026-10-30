WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        rs.ps_partkey,
        rs.supplier_name,
        rs.total_available_quantity,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrdersWithPopularity AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        li.l_partkey,
        SUM(li.l_quantity) AS total_quantity_ordered
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, li.l_partkey
),
PopularParts AS (
    SELECT 
        lw.l_partkey,
        SUM(lw.total_quantity_ordered) AS total_quantity
    FROM 
        OrdersWithPopularity lw
    GROUP BY 
        lw.l_partkey
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    ps.ps_partkey,
    pp.p_name,
    ps.total_available_quantity,
    ps.total_supply_cost,
    cp.c_custkey,
    cp.c_name,
    cp.total_orders,
    cp.total_spent
FROM 
    TopSuppliers ps
JOIN 
    part pp ON ps.ps_partkey = pp.p_partkey
JOIN 
    PopularParts pop ON ps.ps_partkey = pop.l_partkey
JOIN 
    CustomerOrders cp ON cp.total_orders > 5
ORDER BY 
    ps.total_available_quantity DESC, ps.total_supply_cost ASC;
