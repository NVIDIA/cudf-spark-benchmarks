WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_value,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        co.c_name AS customer_name,
        COALESCE(SUM(co.total_order_value), 0) AS total_customer_orders,
        COALESCE(SUM(rs.total_supply_cost), 0) AS total_supplier_costs
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    LEFT JOIN 
        CustomerOrders co ON rs.s_suppkey = co.o_orderkey
    GROUP BY 
        r.r_name, n.n_name, rs.s_name, co.c_name
)
SELECT 
    region_name, 
    nation_name, 
    supplier_name, 
    customer_name, 
    total_customer_orders, 
    total_supplier_costs
FROM 
    FinalReport
ORDER BY 
    region_name, nation_name, supplier_name, customer_name;
