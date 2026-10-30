WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value, 
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name
),
JoinedDetails AS (
    SELECT 
        od.o_orderkey, 
        od.c_custkey, 
        od.c_name, 
        sd.s_suppkey, 
        sd.s_name, 
        sd.nation_name, 
        sd.region_name, 
        od.total_order_value, 
        od.lineitem_count, 
        sd.total_available_quantity, 
        sd.total_supply_value
    FROM 
        OrderDetails od
    JOIN 
        SupplierDetails sd ON od.lineitem_count <= (SELECT AVG(lineitem_count) FROM OrderDetails)
)
SELECT 
    j.o_orderkey, 
    j.c_name, 
    j.s_name, 
    j.nation_name, 
    j.region_name, 
    j.total_order_value, 
    j.total_available_quantity, 
    j.total_supply_value
FROM 
    JoinedDetails j
ORDER BY 
    j.total_order_value DESC
LIMIT 100;