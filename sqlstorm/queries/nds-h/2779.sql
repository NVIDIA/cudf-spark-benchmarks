WITH SalesInfo AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierNation AS (
    SELECT 
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    r.r_name AS region,
    COALESCE(SUM(si.sales), 0) AS total_sales,
    COALESCE(MAX(t.rank), 0) AS max_rank,
    COALESCE(SUM(sn.total_cost), 0) AS total_supplier_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    SalesInfo si ON o.o_orderkey = si.l_orderkey
LEFT JOIN 
    TopOrders t ON o.o_orderkey = t.o_orderkey
LEFT JOIN 
    SupplierNation sn ON n.n_name = sn.n_name
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC, r.r_name;