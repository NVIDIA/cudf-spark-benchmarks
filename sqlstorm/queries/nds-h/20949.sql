
WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderLineDiscounts AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price,
        MIN(CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END) AS return_status
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
),
PartMarketSegments AS (
    SELECT
        p.p_partkey,
        p.p_brand,
        COUNT(DISTINCT c.c_custkey) AS customers_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM
        part p
    LEFT JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        p.p_size IN (5, 10) AND p.p_retailprice IS NOT NULL
    GROUP BY
        p.p_partkey, p.p_brand
)
SELECT
    p.p_name,
    sd.s_name,
    pms.customers_count,
    pms.total_order_value,
    CASE 
        WHEN pms.total_order_value IS NULL THEN 'No orders' 
        ELSE 'Order present' 
    END AS order_status,
    COALESCE(od.total_discounted_price, 0) AS total_discounted_price,
    sd.total_supply_cost
FROM
    part p
LEFT JOIN
    SupplierDetails sd ON sd.rn = 1 
LEFT JOIN
    PartMarketSegments pms ON p.p_partkey = pms.p_partkey
LEFT JOIN
    OrderLineDiscounts od ON od.l_orderkey IN (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l
        WHERE 
            l.l_partkey = p.p_partkey
        GROUP BY 
            l.l_orderkey
        HAVING 
            SUM(l.l_quantity) > COALESCE(NULLIF(SUM(l.l_discount), 0), 1)
    )
WHERE
    p.p_retailprice BETWEEN 100.00 AND 500.00
ORDER BY
    total_discounted_price DESC, p.p_name ASC;
