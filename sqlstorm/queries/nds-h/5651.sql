WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        revenue DESC
    LIMIT 10
)
SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    s.s_name AS supplier_name,
    t.p_name AS top_product,
    rd.region_name,
    rd.nation_name
FROM 
    RankedOrders o
JOIN 
    SupplierDetails s ON o.o_orderkey = s.s_suppkey
JOIN 
    TopProducts t ON o.o_orderkey = t.p_partkey
CROSS JOIN 
    (SELECT DISTINCT r.r_name AS region_name, n.n_name AS nation_name 
     FROM region r 
     JOIN nation n ON r.r_regionkey = n.n_regionkey) rd
WHERE 
    o.rank <= 5
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;