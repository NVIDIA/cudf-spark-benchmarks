SELECT 
    nation.n_name AS nation_name,
    region.r_name AS region_name,
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_revenue,
    AVG(lineitem.l_quantity) AS avg_quantity_ordered
FROM 
    lineitem
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN 
    customer ON orders.o_custkey = customer.c_custkey
JOIN 
    supplier ON lineitem.l_suppkey = supplier.s_suppkey
JOIN 
    partsupp ON lineitem.l_partkey = partsupp.ps_partkey AND supplier.s_suppkey = partsupp.ps_suppkey
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey
JOIN 
    region ON nation.n_regionkey = region.r_regionkey
WHERE 
    lineitem.l_shipdate >= '1997-01-01' AND lineitem.l_shipdate < '1998-01-01'
GROUP BY 
    nation.n_name, region.r_name
ORDER BY 
    total_revenue DESC, avg_quantity_ordered DESC
LIMIT 10;