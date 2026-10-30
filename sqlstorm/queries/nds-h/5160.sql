WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        row_number() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        l.l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.num_parts
    FROM 
        SupplierDetails sd
    WHERE 
        sd.num_parts > 5
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    hvl.total_revenue,
    ts.s_name AS top_supplier_name,
    ts.num_parts AS supplier_part_count
FROM 
    RankedOrders ro
JOIN 
    HighValueLineItems hvl ON ro.o_orderkey = hvl.l_orderkey
JOIN 
    lineitem l ON hvl.l_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_orderdate DESC, hvl.total_revenue DESC
LIMIT 
    100;