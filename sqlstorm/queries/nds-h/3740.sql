WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
SuppliersWithParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_shipdate,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate <= cast('1998-10-01' as date) AND 
        l.l_tax > 0
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    s.s_name,
    p.p_name,
    ld.l_quantity,
    ld.l_extendedprice * (1 - ld.l_discount) AS net_price,
    RANK() OVER (PARTITION BY o.o_orderkey ORDER BY ld.l_extendedprice DESC) AS item_rank
FROM 
    RankedOrders o
JOIN 
    LineItemDetails ld ON o.o_orderkey = ld.l_orderkey
LEFT JOIN 
    partsupp ps ON ld.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON ld.l_partkey = p.p_partkey
WHERE 
    s.s_suppkey IN (SELECT s1.s_suppkey FROM SuppliersWithParts s1 WHERE s1.part_count > 5)
    AND (ld.l_discount > 0.1 OR ld.l_tax IS NULL)
ORDER BY 
    o.o_orderdate ASC, net_price DESC;