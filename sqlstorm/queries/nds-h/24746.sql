
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(li.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(p.p_retailprice) AS max_retail_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 1000 AND MAX(p.p_retailprice) < 50.00
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        (SELECT COUNT(DISTINCT s.s_suppkey) 
         FROM supplier s 
         WHERE s.s_nationkey = n.n_nationkey) AS supplier_count
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%land%')
)

SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.total_avail_qty,
    tp.max_retail_price,
    tn.n_name AS nation_name,
    rs.s_name AS top_supplier_name,
    ho.o_orderkey,
    ho.o_totalprice,
    ho.o_orderdate
FROM 
    FilteredParts tp
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (
        SELECT MIN(rs_inner.s_suppkey)
        FROM RankedSuppliers rs_inner 
        WHERE rs_inner.s_nationkey = (SELECT MIN(c.c_nationkey) FROM customer c WHERE c.c_acctbal > 1000)
        AND rs_inner.supplier_rank = 1
    )
LEFT JOIN 
    TopNations tn ON tn.n_nationkey = rs.s_nationkey
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey = (
        SELECT MIN(ho_inner.o_orderkey) 
        FROM HighValueOrders ho_inner 
        WHERE ho_inner.item_count = (
            SELECT MAX(item_count) FROM HighValueOrders
        )
    )
ORDER BY 
    tp.max_retail_price DESC, 
    ho.o_orderdate ASC
LIMIT 10;
