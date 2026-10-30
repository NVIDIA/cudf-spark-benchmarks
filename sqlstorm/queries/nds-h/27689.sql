
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        r.r_name,
        n.n_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        lineitem l ON l.l_suppkey = s.s_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        rs.rank = 1
    GROUP BY 
        s.s_name, r.r_name, n.n_name
)
SELECT 
    ts.s_name,
    SUM(rs.total_avail_qty) AS total_quantity,
    ts.order_count,
    CONCAT(ts.s_name, ' from ', ts.r_name, ' region, serves ', ts.order_count, ' orders.') AS supplier_info
FROM 
    TopSuppliers ts
JOIN 
    RankedSuppliers rs ON ts.s_name = rs.s_name
GROUP BY 
    ts.s_name, ts.order_count, ts.r_name
ORDER BY 
    total_quantity DESC;
