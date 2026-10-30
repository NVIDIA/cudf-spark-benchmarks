
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_comment, 
        SUBSTRING(s.s_name FROM 1 FOR 10) AS short_name,
        CHAR_LENGTH(s.s_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1998-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        CONCAT(p.p_name, ' - ', p.p_comment) AS part_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size > 10 
)
SELECT 
    rs.short_name AS supplier_short_name,
    rs.comment_length, 
    fo.o_orderkey, 
    fo.o_orderdate, 
    fo.o_totalprice, 
    ps.part_info
FROM 
    RankedSuppliers rs
JOIN 
    FilteredOrders fo ON rs.rank <= 5
JOIN 
    PartSupplierDetails ps ON ps.ps_supplycost < fo.o_totalprice
WHERE 
    rs.s_comment LIKE '%high priority%'
ORDER BY 
    fo.o_orderdate DESC, 
    rs.comment_length DESC;
