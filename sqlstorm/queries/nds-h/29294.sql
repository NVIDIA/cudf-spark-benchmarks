WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_size IN (12, 28, 55)
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT * FROM RankedSuppliers WHERE rank <= 3
)
SELECT 
    tp.p_name,
    tp.total_quantity,
    tp.avg_price,
    ts.s_name,
    ts.nation 
FROM 
    FilteredParts tp 
JOIN 
    lineitem l ON tp.p_partkey = l.l_partkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    tp.total_quantity > 100
ORDER BY 
    tp.avg_price DESC, tp.total_quantity DESC;
