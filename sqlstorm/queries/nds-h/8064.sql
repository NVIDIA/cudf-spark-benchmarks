WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
RankedSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.total_supply_cost,
        RANK() OVER (PARTITION BY sd.nation_name ORDER BY sd.total_supply_cost DESC) AS rank
    FROM 
        SupplierDetails sd
),
RankedCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.total_order_value,
        RANK() OVER (ORDER BY co.total_order_value DESC) AS customer_rank
    FROM 
        CustomerOrders co
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.nation_name,
    rc.c_custkey,
    rc.c_name,
    rc.total_order_value
FROM 
    RankedSuppliers rs
JOIN 
    RankedCustomers rc ON rs.rank <= 5 AND rc.customer_rank <= 10
ORDER BY 
    rs.nation_name, rs.total_supply_cost DESC, rc.total_order_value DESC;
