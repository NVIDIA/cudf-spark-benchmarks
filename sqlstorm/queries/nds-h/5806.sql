
WITH RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
)
SELECT 
    rd.o_orderkey,
    rd.o_orderdate,
    SUM(rd.total_revenue) AS order_revenue,
    sd.s_name AS supplier_name,
    sd.nation_name,
    sd.region_name,
    sd.total_quantity,
    ps.total_supplycost
FROM 
    RecentOrders rd
JOIN 
    PartSupplier ps ON rd.o_orderkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
GROUP BY 
    rd.o_orderkey, rd.o_orderdate, sd.s_name, sd.nation_name, sd.region_name, sd.total_quantity, ps.total_supplycost
HAVING 
    SUM(rd.total_revenue) > 10000
ORDER BY 
    order_revenue DESC
LIMIT 100;
