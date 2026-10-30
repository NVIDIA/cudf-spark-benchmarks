
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_size,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 1 AND 50
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_cost) FROM (
            SELECT 
                SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
            FROM 
                supplier s2
            JOIN 
                partsupp ps ON s2.s_suppkey = ps.ps_suppkey
            GROUP BY 
                s2.s_suppkey
        ) AS avg_cost)
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_container,
    rp.p_size,
    ts.s_name AS supplier_name,
    ts.nation,
    rp.ps_availqty,
    rp.ps_supplycost
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.ps_availqty > 1000
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_brand, rp.p_name;
