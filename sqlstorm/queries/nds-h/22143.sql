WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity * (1 - l.l_discount)) AS total_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        COALESCE(t.total_quantity, 0) AS total_quantity
    FROM 
        orders o
    LEFT JOIN 
        TotalLineItems t ON o.o_orderkey = t.l_orderkey
    WHERE 
        o.o_totalprice > (
            SELECT 
                AVG(o2.o_totalprice)
            FROM 
                orders o2
            WHERE 
                o2.o_orderdate < o.o_orderdate
        )
), 
ExtendedOrderData AS (
    SELECT 
        h.o_orderkey,
        h.o_totalprice,
        h.o_orderdate,
        h.o_orderstatus,
        ps.ps_supplycost,
        p.p_size,
        CASE 
            WHEN p.p_size IS NULL THEN 'SIZE UNKNOWN'
            ELSE p.p_name
        END AS item_description
    FROM 
        HighValueOrders h
    LEFT JOIN 
        partsupp ps ON h.o_orderkey = ps.ps_partkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)

SELECT 
    e.o_orderkey,
    e.o_totalprice,
    e.o_orderdate,
    e.o_orderstatus,
    s.s_name AS supplier_name,
    e.item_description,
    e.ps_supplycost,
    CASE 
        WHEN s.rn IS NOT NULL THEN 'Supplier Ranked'
        ELSE 'Supplier Unranked'
    END AS supplier_rank_status
FROM 
    ExtendedOrderData e
LEFT JOIN 
    RankedSuppliers s ON e.o_orderkey = s.s_suppkey
WHERE 
    e.o_orderstatus NOT IN ('F', 'O')
ORDER BY 
    e.o_orderdate DESC, 
    e.o_totalprice DESC
LIMIT 100;