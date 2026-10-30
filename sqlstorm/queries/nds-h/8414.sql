
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
SupplierDetails AS (
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
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.total_supply_cost,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost > 10000
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_extendedprice,
        o.o_orderstatus
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
)

SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus,
    ts.s_name AS supplier_name,
    oli.l_partkey,
    SUM(oli.l_quantity) AS total_quantity,
    SUM(oli.l_extendedprice) AS total_revenue,
    AVG(oli.l_discount) AS average_discount
FROM 
    RankedOrders ro
JOIN 
    OrderLineItems oli ON ro.o_orderkey = oli.l_orderkey
JOIN 
    TopSuppliers ts ON oli.l_partkey = ts.s_suppkey
WHERE 
    ro.order_rank <= 10
GROUP BY 
    ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus, ts.s_name, oli.l_partkey
ORDER BY 
    ro.o_orderdate DESC, total_revenue DESC;
