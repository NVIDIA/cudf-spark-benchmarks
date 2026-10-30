
WITH RegionalSupplierInfo AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name, s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate <= DATE '1997-01-01'
),
SupplierOrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice, 
        l.l_discount, 
        l.l_tax,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l
)

SELECT 
    rsi.nation_name,
    rsi.region_name,
    COUNT(DISTINCT sod.l_orderkey) AS total_orders,
    SUM(sod.net_price) AS total_net_value,
    AVG(sod.l_quantity) AS avg_quantity,
    MAX(rsi.total_cost) AS max_supplier_cost
FROM 
    RegionalSupplierInfo rsi
JOIN 
    SupplierOrderDetails sod ON rsi.s_suppkey = sod.l_suppkey
JOIN 
    HighValueOrders hvo ON sod.l_orderkey = hvo.o_orderkey
WHERE 
    hvo.order_rank <= 10
GROUP BY 
    rsi.nation_name, rsi.region_name, rsi.total_cost
HAVING 
    SUM(sod.net_price) > 1000000
ORDER BY 
    total_net_value DESC;
