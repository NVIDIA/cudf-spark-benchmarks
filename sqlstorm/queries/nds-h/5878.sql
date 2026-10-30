WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
TopParts AS (
    SELECT
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        rp.total_available_quantity,
        rp.total_supply_cost
    FROM
        RankedParts rp
    WHERE
        rp.rank <= 5
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    ORDER BY
        total_spent DESC
    LIMIT 10
)
SELECT
    cos.c_custkey,
    cos.c_name,
    tp.p_partkey,
    tp.p_name,
    tp.p_brand,
    tp.p_retailprice,
    tp.total_available_quantity,
    cos.total_spent,
    cos.total_orders
FROM
    CustomerOrderSummary cos
JOIN
    TopParts tp ON tp.total_available_quantity > 100
ORDER BY
    cos.total_spent DESC, tp.p_retailprice ASC;
